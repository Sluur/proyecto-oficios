from django.contrib import admin
from .models import Resena


@admin.register(Resena)
class ResenaAdmin(admin.ModelAdmin):
    list_display = ('autor', 'destinatario', 'puntaje', 'solicitud', 'created_at')
    list_filter = ('puntaje', 'created_at')
    search_fields = ('autor__username', 'destinatario__username', 'comentario')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    raw_id_fields = ('solicitud', 'autor', 'destinatario')
