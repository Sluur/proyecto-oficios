from django.urls import path
from .views import ResenaDeSolicitudView, ResenaDeUsuarioView

urlpatterns = [
    path(
        'solicitudes/<int:solicitud_pk>/resenas/',
        ResenaDeSolicitudView.as_view(),
        name='resenas-de-solicitud',
    ),
    path(
        'usuarios/<int:usuario_pk>/resenas/',
        ResenaDeUsuarioView.as_view(),
        name='resenas-de-usuario',
    ),
]
