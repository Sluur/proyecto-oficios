from django.db import models


class OficioCategoria(models.Model):
    nombre = models.CharField(max_length=100, unique=True)
    icono = models.CharField(max_length=50)
    descripcion = models.TextField(blank=True)
    activa = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'categoría de oficio'
        verbose_name_plural = 'categorías de oficios'
        ordering = ['nombre']

    def __str__(self):
        return self.nombre
