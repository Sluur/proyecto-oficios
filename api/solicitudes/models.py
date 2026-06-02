from django.db import models
from django.conf import settings
from django.contrib.gis.db import models as gis_models


class Solicitud(models.Model):

    ESTADO_CHOICES = [
        ('abierta', 'Abierta'),
        ('en_progreso', 'En progreso'),
        ('cerrada', 'Cerrada'),
        ('cancelada', 'Cancelada'),
    ]

    titulo = models.CharField(max_length=200)
    descripcion = models.TextField(blank=True)
    foto = models.ImageField(upload_to='solicitudes/', blank=True, null=True)
    ubicacion = gis_models.PointField(srid=4326)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='abierta')
    cliente = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='solicitudes',
    )
    trabajador_aceptado = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='trabajos',
    )
    categoria = models.ForeignKey(
        'oficios.OficioCategoria',
        on_delete=models.PROTECT,
        related_name='solicitudes',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'solicitud'
        verbose_name_plural = 'solicitudes'
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.estado.upper()}] {self.titulo} — {self.cliente}'


class Propuesta(models.Model):

    ESTADO_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('aceptada', 'Aceptada'),
        ('rechazada', 'Rechazada'),
    ]

    solicitud = models.ForeignKey(
        Solicitud,
        on_delete=models.CASCADE,
        related_name='propuestas',
    )
    trabajador = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='propuestas_enviadas',
    )
    precio_estimado = models.DecimalField(max_digits=10, decimal_places=2)
    mensaje = models.TextField(blank=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='pendiente')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'propuesta'
        verbose_name_plural = 'propuestas'
        unique_together = [('solicitud', 'trabajador')]
        ordering = ['-created_at']

    def __str__(self):
        return f'Propuesta de {self.trabajador} a {self.solicitud} — ${self.precio_estimado}'
