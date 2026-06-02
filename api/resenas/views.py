from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from solicitudes.models import Solicitud
from .models import Resena
from .serializers import ResenaCreateSerializer, ResenaSerializer


class ResenaDeSolicitudView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_solicitud(self, pk):
        return get_object_or_404(Solicitud, pk=pk)

    def post(self, request, solicitud_pk):
        solicitud = self._get_solicitud(solicitud_pk)

        if solicitud.estado != 'cerrada':
            return Response(
                {'detail': f'La solicitud está en estado "{solicitud.estado}". Solo se puede reseñar cuando está cerrada.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if request.user not in (solicitud.cliente, solicitud.trabajador_aceptado):
            return Response(
                {'detail': 'Solo los participantes del trabajo pueden dejar reseñas.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if Resena.objects.filter(solicitud=solicitud, autor=request.user).exists():
            return Response(
                {'detail': 'Ya dejaste una reseña para esta solicitud.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = ResenaCreateSerializer(
            data=request.data,
            context={'request': request, 'solicitud': solicitud},
        )
        serializer.is_valid(raise_exception=True)
        resena = serializer.save()
        return Response(ResenaSerializer(resena).data, status=status.HTTP_201_CREATED)


class ResenaDeUsuarioView(generics.ListAPIView):
    serializer_class = ResenaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Resena.objects.filter(
            destinatario_id=self.kwargs['usuario_pk']
        ).select_related('autor', 'destinatario', 'solicitud')
