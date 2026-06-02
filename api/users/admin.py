from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Usuario


@admin.register(Usuario)
class UsuarioAdmin(UserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'rol', 'verificado', 'activo', 'is_staff')
    list_filter = ('rol', 'verificado', 'activo', 'is_staff', 'is_superuser')
    search_fields = ('username', 'email', 'first_name', 'last_name', 'telefono')
    ordering = ('-date_joined',)
    list_editable = ('verificado', 'activo')

    fieldsets = UserAdmin.fieldsets + (
        ('Datos del perfil', {
            'fields': ('rol', 'foto', 'telefono', 'ubicacion', 'verificado', 'activo', 'fcm_token', 'oficios')
        }),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Datos del perfil', {
            'fields': ('rol', 'email')
        }),
    )
