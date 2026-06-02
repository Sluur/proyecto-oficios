from django.contrib import admin
from .models import Solicitud, Propuesta


class PropuestaInline(admin.TabularInline):
    model = Propuesta
    extra = 0
    readonly_fields = ('created_at',)
    fields = ('trabajador', 'precio_estimado', 'mensaje', 'estado', 'created_at')


@admin.register(Solicitud)
class SolicitudAdmin(admin.ModelAdmin):
    list_display = ('titulo', 'cliente', 'categoria', 'estado', 'created_at', 'closed_at')
    list_filter = ('estado', 'categoria', 'created_at')
    search_fields = ('titulo', 'descripcion', 'cliente__username', 'cliente__email')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    raw_id_fields = ('cliente', 'trabajador_aceptado', 'categoria')
    inlines = [PropuestaInline]


@admin.register(Propuesta)
class PropuestaAdmin(admin.ModelAdmin):
    list_display = ('solicitud', 'trabajador', 'precio_estimado', 'estado', 'created_at')
    list_filter = ('estado', 'created_at')
    search_fields = ('trabajador__username', 'solicitud__titulo')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    raw_id_fields = ('solicitud', 'trabajador')
