from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from oficios.serializers import OficioCategoriaSerializer
from .models import Usuario


class RegistroSerializer(serializers.ModelSerializer):
    nombre = serializers.CharField(write_only=True, required=False, allow_blank=True)
    password = serializers.CharField(
        write_only=True, required=True, validators=[validate_password]
    )

    class Meta:
        model = Usuario
        fields = ('username', 'email', 'password', 'rol', 'nombre')

    def validate_email(self, value):
        if Usuario.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('Ya existe un usuario con este email.')
        return value.lower()

    def validate_rol(self, value):
        if value == 'admin':
            raise serializers.ValidationError('No podés registrarte como administrador.')
        return value

    def create(self, validated_data):
        nombre = validated_data.pop('nombre', '')
        password = validated_data.pop('password')
        user = Usuario(**validated_data)
        user.first_name = nombre
        user.set_password(password)
        user.save()
        return user


class UsuarioSerializer(serializers.ModelSerializer):
    ubicacion = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = (
            'id', 'username', 'email', 'first_name', 'last_name',
            'rol', 'foto', 'telefono', 'ubicacion',
            'verificado', 'activo',
        )
        read_only_fields = ('verificado', 'activo')

    def get_ubicacion(self, obj):
        if obj.ubicacion is None:
            return None
        return {'lat': obj.ubicacion.y, 'lon': obj.ubicacion.x}


class TrabajadorSerializer(serializers.ModelSerializer):
    ubicacion = serializers.SerializerMethodField()
    oficios = OficioCategoriaSerializer(many=True, read_only=True)
    # Estos tres campos vienen anotados desde el ViewSet
    promedio_puntaje = serializers.FloatField(read_only=True, allow_null=True)
    total_resenas = serializers.IntegerField(read_only=True)
    total_trabajos = serializers.IntegerField(read_only=True)

    class Meta:
        model = Usuario
        fields = (
            'id', 'username', 'first_name', 'last_name', 'foto',
            'telefono', 'ubicacion', 'verificado',
            'oficios', 'promedio_puntaje', 'total_resenas', 'total_trabajos',
        )

    def get_ubicacion(self, obj):
        if obj.ubicacion is None:
            return None
        return {'lat': obj.ubicacion.y, 'lon': obj.ubicacion.x}
