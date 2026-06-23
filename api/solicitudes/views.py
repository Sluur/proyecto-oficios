from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.db import transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from users.permissions import IsCliente, IsOwnerOrAdmin, IsTrabajador
from .models import Propuesta, Solicitud
from .serializers import (
    PropuestaCreateSerializer,
    PropuestaSerializer,
    SolicitudCreateSerializer,
    SolicitudSerializer,
)


class SolicitudViewSet(viewsets.ModelViewSet):
    # PUT/PATCH no están en la spec: se bloquean a nivel HTTP
    http_method_names = ['get', 'post', 'delete', 'head', 'options']

    def get_serializer_class(self):
        if self.action == 'create':
            return SolicitudCreateSerializer
        return SolicitudSerializer

    def get_permissions(self):
        if self.action == 'create':
            return [IsCliente()]
        if self.action == 'destroy':
            return [IsOwnerOrAdmin()]
        return [IsAuthenticated()]

    def get_queryset(self):
        qs = Solicitud.objects.select_related(
            'cliente', 'trabajador_aceptado', 'categoria'
        )

        lat = self.request.query_params.get('lat')
        lon = self.request.query_params.get('lon')
        if lat and lon:
            try:
                radio = float(self.request.query_params.get('radio', 10))
                punto = Point(float(lon), float(lat), srid=4326)
                qs = qs.filter(ubicacion__distance_lte=(punto, D(km=radio)))
            except (ValueError, TypeError):
                pass

        categoria = self.request.query_params.get('categoria')
        if categoria:
            qs = qs.filter(categoria_id=categoria)

        estado = self.request.query_params.get('estado')
        if estado:
            qs = qs.filter(estado=estado)

        return qs

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        solicitud = serializer.save()
        return Response(
            SolicitudSerializer(solicitud, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['get'])
    def mis(self, request):
        qs = Solicitud.objects.filter(
            Q(cliente=request.user) | Q(trabajador_aceptado=request.user)
        ).select_related('cliente', 'trabajador_aceptado', 'categoria')
        serializer = SolicitudSerializer(qs, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def cerrar(self, request, pk=None):
        solicitud = self.get_object()

        if request.user not in (solicitud.cliente, solicitud.trabajador_aceptado):
            return Response(
                {'detail': 'Solo los participantes pueden cerrar la solicitud.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if solicitud.estado != 'en_progreso':
            return Response(
                {'detail': f'La solicitud está en estado "{solicitud.estado}", debe estar en_progreso.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        solicitud.estado = 'cerrada'
        solicitud.closed_at = timezone.now()
        solicitud.save(update_fields=['estado', 'closed_at'])

        return Response(SolicitudSerializer(solicitud, context={'request': request}).data)


class PropuestaDeSolicitudViewSet(viewsets.GenericViewSet):
    """Maneja GET y POST en /solicitudes/{solicitud_pk}/propuestas/."""

    def get_permissions(self):
        if self.action == 'create':
            return [IsTrabajador()]
        return [IsAuthenticated()]

    def _get_solicitud(self):
        return get_object_or_404(Solicitud, pk=self.kwargs['solicitud_pk'])

    def list(self, request, *args, **kwargs):
        solicitud = self._get_solicitud()
        if request.user != solicitud.cliente and not (
            request.user.is_staff or request.user.rol == 'admin'
        ):
            return Response(
                {'detail': 'Solo el cliente dueño puede ver las propuestas.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        qs = Propuesta.objects.filter(solicitud=solicitud).select_related(
            'trabajador', 'solicitud__cliente'
        )
        return Response(PropuestaSerializer(qs, many=True).data)

    def create(self, request, *args, **kwargs):
        solicitud = self._get_solicitud()

        if solicitud.estado != 'abierta':
            return Response(
                {'detail': f'La solicitud está en estado "{solicitud.estado}", solo se aceptan propuestas cuando está abierta.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if Propuesta.objects.filter(solicitud=solicitud, trabajador=request.user).exists():
            return Response(
                {'detail': 'Ya enviaste una propuesta para esta solicitud.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = PropuestaCreateSerializer(
            data=request.data,
            context={'request': request, 'solicitud': solicitud},
        )
        serializer.is_valid(raise_exception=True)
        propuesta = serializer.save()
        return Response(
            PropuestaSerializer(propuesta).data,
            status=status.HTTP_201_CREATED,
        )


class PropuestaViewSet(viewsets.GenericViewSet):
    """Maneja /propuestas/mis/ y /propuestas/{pk}/aceptar/."""

    queryset = Propuesta.objects.select_related(
        'solicitud', 'solicitud__cliente', 'trabajador', 'solicitud__categoria'
    )

    def get_permissions(self):
        if self.action == 'mis':
            return [IsTrabajador()]
        return [IsAuthenticated()]

    @action(detail=False, methods=['get'])
    def mis(self, request):
        qs = self.get_queryset().filter(trabajador=request.user)
        return Response(PropuestaSerializer(qs, many=True).data)

    @action(detail=True, methods=['post'])
    def aceptar(self, request, pk=None):
        propuesta = self.get_object()
        solicitud = propuesta.solicitud

        if request.user != solicitud.cliente:
            return Response(
                {'detail': 'Solo el cliente dueño puede aceptar propuestas.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if solicitud.estado != 'abierta':
            return Response(
                {'detail': f'La solicitud está en estado "{solicitud.estado}", solo se puede aceptar si está abierta.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            solicitud.estado = 'en_progreso'
            solicitud.trabajador_aceptado = propuesta.trabajador
            solicitud.save(update_fields=['estado', 'trabajador_aceptado'])

            propuesta.estado = 'aceptada'
            propuesta.save(update_fields=['estado'])

            Propuesta.objects.filter(solicitud=solicitud).exclude(pk=propuesta.pk).update(
                estado='rechazada'
            )

        return Response(PropuestaSerializer(propuesta).data)
