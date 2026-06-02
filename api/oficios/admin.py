from django.contrib import admin
from .models import OficioCategoria


@admin.register(OficioCategoria)
class OficioCategoriaAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'icono', 'activa', 'created_at')
    list_filter = ('activa',)
    search_fields = ('nombre', 'descripcion')
    list_editable = ('activa',)
    ordering = ('nombre',)
    readonly_fields = ('created_at',)
