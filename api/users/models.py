from django.contrib.auth.models import AbstractUser
from django.contrib.gis.db import models as gis_models
from django.db import models
from .managers import UsuarioManager


class Usuario(AbstractUser):

    ROL_CHOICES = [
        ('cliente', 'Cliente'),
        ('trabajador', 'Trabajador'),
        ('admin', 'Administrador'),
    ]

    rol = models.CharField(max_length=20, choices=ROL_CHOICES)
    foto = models.ImageField(upload_to='perfiles/', blank=True, null=True)
    telefono = models.CharField(max_length=20, blank=True, null=True)
    ubicacion = gis_models.PointField(srid=4326, blank=True, null=True)
    verificado = models.BooleanField(default=False)
    activo = models.BooleanField(default=True)
    bio = models.TextField(blank=True, null=True)
    fcm_token = models.TextField(blank=True, null=True)
    oficios = models.ManyToManyField(
        'oficios.OficioCategoria',
        blank=True,
        related_name='trabajadores',
        db_table='users_trabajador_oficios',
    )

    objects = UsuarioManager()

    class Meta:
        verbose_name = 'usuario'
        verbose_name_plural = 'usuarios'

    def __str__(self):
        return f'{self.username} ({self.rol})'

    @property
    def es_trabajador(self):
        return self.rol == 'trabajador'

    @property
    def es_cliente(self):
        return self.rol == 'cliente'
