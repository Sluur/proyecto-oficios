from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator


class Resena(models.Model):
    solicitud = models.ForeignKey(
        'solicitudes.Solicitud',
        on_delete=models.PROTECT,
        related_name='resenas',
    )
    autor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='resenas_escritas',
    )
    destinatario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='resenas_recibidas',
    )
    puntaje = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comentario = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'reseña'
        verbose_name_plural = 'reseñas'
        unique_together = [('solicitud', 'autor')]
        ordering = ['-created_at']

    def __str__(self):
        return f'Reseña de {self.autor} → {self.destinatario} ({self.puntaje}★)'
