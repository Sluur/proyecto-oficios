from django.contrib.gis.geos import Point
from rest_framework import serializers
from oficios.serializers import OficioCategoriaSerializer
from users.models import Usuario
from .models import Propuesta, Solicitud


class UsuarioResumenSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ('id', 'username', 'first_name', 'last_name', 'foto', 'telefono', 'rol', 'verificado')


class SolicitudSerializer(serializers.ModelSerializer):
    cliente = UsuarioResumenSerializer(read_only=True)
    trabajador_aceptado = UsuarioResumenSerializer(read_only=True)
    categoria = OficioCategoriaSerializer(read_only=True)
    ubicacion = serializers.SerializerMethodField()

    class Meta:
        model = Solicitud
        fields = (
            'id', 'titulo', 'descripcion', 'foto', 'ubicacion',
            'estado', 'cliente', 'trabajador_aceptado', 'categoria',
            'created_at', 'closed_at',
        )

    def get_ubicacion(self, obj):
        if obj.ubicacion is None:
            return None
        return {'lat': obj.ubicacion.y, 'lon': obj.ubicacion.x}


class SolicitudCreateSerializer(serializers.ModelSerializer):
    lat = serializers.FloatField(write_only=True)
    lon = serializers.FloatField(write_only=True)

    class Meta:
        model = Solicitud
        fields = ('titulo', 'descripcion', 'foto', 'lat', 'lon', 'categoria')

    def validate_lat(self, value):
        if not (-90 <= value <= 90):
            raise serializers.ValidationError('Latitud debe estar entre -90 y 90.')
        return value

    def validate_lon(self, value):
        if not (-180 <= value <= 180):
            raise serializers.ValidationError('Longitud debe estar entre -180 y 180.')
        return value

    def create(self, validated_data):
        lat = validated_data.pop('lat')
        lon = validated_data.pop('lon')
        validated_data['ubicacion'] = Point(lon, lat, srid=4326)
        validated_data['cliente'] = self.context['request'].user
        return super().create(validated_data)


class PropuestaSerializer(serializers.ModelSerializer):
    trabajador = UsuarioResumenSerializer(read_only=True)
    solicitud_titulo = serializers.CharField(source='solicitud.titulo', read_only=True)
    solicitud_cliente_telefono = serializers.CharField(
        source='solicitud.cliente.telefono', read_only=True
    )

    class Meta:
        model = Propuesta
        fields = (
            'id', 'solicitud', 'solicitud_titulo', 'solicitud_cliente_telefono',
            'trabajador', 'precio_estimado', 'mensaje', 'estado', 'created_at',
        )
        read_only_fields = ('estado', 'created_at')


class PropuestaCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Propuesta
        fields = ('precio_estimado', 'mensaje')

    def create(self, validated_data):
        validated_data['solicitud'] = self.context['solicitud']
        validated_data['trabajador'] = self.context['request'].user
        return super().create(validated_data)
