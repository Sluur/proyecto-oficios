from rest_framework import serializers
from users.models import Usuario
from .models import Resena


class UsuarioResumenSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ('id', 'username', 'first_name', 'last_name', 'foto', 'rol', 'verificado')


class ResenaSerializer(serializers.ModelSerializer):
    autor = UsuarioResumenSerializer(read_only=True)
    destinatario = UsuarioResumenSerializer(read_only=True)

    class Meta:
        model = Resena
        fields = ('id', 'solicitud', 'autor', 'destinatario', 'puntaje', 'comentario', 'created_at')
        read_only_fields = ('created_at',)


class ResenaCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Resena
        fields = ('puntaje', 'comentario')

    def create(self, validated_data):
        solicitud = self.context['solicitud']
        autor = self.context['request'].user

        # El destinatario siempre es el otro participante
        if autor == solicitud.cliente:
            destinatario = solicitud.trabajador_aceptado
        else:
            destinatario = solicitud.cliente

        validated_data['solicitud'] = solicitud
        validated_data['autor'] = autor
        validated_data['destinatario'] = destinatario
        return super().create(validated_data)
