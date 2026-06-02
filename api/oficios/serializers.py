from rest_framework import serializers
from .models import OficioCategoria


class OficioCategoriaSerializer(serializers.ModelSerializer):
    class Meta:
        model = OficioCategoria
        fields = ('id', 'nombre', 'icono', 'descripcion', 'activa', 'created_at')
        read_only_fields = ('created_at',)
