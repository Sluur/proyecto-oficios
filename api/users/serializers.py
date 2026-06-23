import random
import re
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from oficios.serializers import OficioCategoriaSerializer
from .models import Usuario


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        del self.fields[self.username_field]
        self.fields['email'] = serializers.EmailField()

    def validate(self, attrs):
        email = attrs.pop('email', '').strip().lower()
        try:
            user = Usuario.objects.get(email__iexact=email)
        except Usuario.DoesNotExist:
            raise serializers.ValidationError(
                {'email': 'No existe una cuenta con este email.'}
            )
        attrs[self.username_field] = user.username
        return super().validate(attrs)


class RegistroSerializer(serializers.ModelSerializer):
    nombre = serializers.CharField(write_only=True, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, required=True)
    username = serializers.CharField(required=False, allow_blank=True, max_length=150)

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
        hint = validated_data.pop('username', '') or ''
        if not hint:
            hint = validated_data['email'].split('@')[0]
        validated_data['username'] = self._unique_username(hint)
        user = Usuario(**validated_data)
        user.first_name = nombre
        user.set_password(password)
        user.save()
        return user

    @staticmethod
    def _unique_username(hint):
        base = re.sub(r'[^\w]', '_', hint).lower()[:25]
        if not Usuario.objects.filter(username=base).exists():
            return base
        for _ in range(20):
            candidate = f'{base}{random.randint(1, 9999)}'
            if not Usuario.objects.filter(username=candidate).exists():
                return candidate
        return f'{base}{random.randint(10000, 99999)}'


class UsuarioSerializer(serializers.ModelSerializer):
    ubicacion = serializers.SerializerMethodField()
    oficios_ids = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = (
            'id', 'username', 'email', 'first_name', 'last_name',
            'rol', 'foto', 'telefono', 'bio', 'ubicacion',
            'verificado', 'activo', 'oficios_ids',
        )
        read_only_fields = ('verificado', 'activo')

    def get_ubicacion(self, obj):
        if obj.ubicacion is None:
            return None
        return {'lat': obj.ubicacion.y, 'lon': obj.ubicacion.x}

    def get_oficios_ids(self, obj):
        if obj.rol == 'trabajador':
            return list(obj.oficios.values_list('id', flat=True))
        return []


class PerfilUpdateSerializer(serializers.ModelSerializer):
    oficios_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False,
    )

    class Meta:
        model = Usuario
        fields = ('first_name', 'last_name', 'telefono', 'bio', 'foto', 'oficios_ids')

    def update(self, instance, validated_data):
        oficios_ids = validated_data.pop('oficios_ids', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if oficios_ids is not None and instance.rol == 'trabajador':
            from oficios.models import OficioCategoria
            instance.oficios.set(OficioCategoria.objects.filter(id__in=oficios_ids))
        return instance


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
