from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.db.models import Avg, Count, Q
from rest_framework import status, viewsets
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import Usuario
from .serializers import (
    EmailTokenObtainPairSerializer,
    PerfilUpdateSerializer,
    RegistroSerializer,
    TrabajadorSerializer,
    UsuarioSerializer,
)


class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer


class RegistroView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegistroSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UsuarioSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)


class MeView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        return Response(UsuarioSerializer(request.user, context={'request': request}).data)

    def patch(self, request):
        serializer = PerfilUpdateSerializer(
            request.user, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UsuarioSerializer(user, context={'request': request}).data)


class TrabajadorViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = TrabajadorSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Usuario.objects.filter(rol='trabajador', activo=True).annotate(
            promedio_puntaje=Avg('resenas_recibidas__puntaje'),
            total_resenas=Count('resenas_recibidas', distinct=True),
            total_trabajos=Count(
                'trabajos',
                filter=Q(trabajos__estado='cerrada'),
                distinct=True,
            ),
        ).prefetch_related('oficios')

        lat = self.request.query_params.get('lat')
        lon = self.request.query_params.get('lon')
        if lat and lon:
            try:
                radio = float(self.request.query_params.get('radio', 10))
                punto = Point(float(lon), float(lat), srid=4326)
                qs = qs.filter(ubicacion__distance_lte=(punto, D(km=radio)))
            except (ValueError, TypeError):
                pass

        oficio = self.request.query_params.get('oficio')
        if oficio:
            qs = qs.filter(oficios__id=oficio).distinct()

        return qs
