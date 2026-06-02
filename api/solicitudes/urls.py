from django.urls import path
from rest_framework.routers import SimpleRouter
from .views import PropuestaDeSolicitudViewSet, PropuestaViewSet, SolicitudViewSet

router = SimpleRouter()
router.register('solicitudes', SolicitudViewSet, basename='solicitud')
router.register('propuestas', PropuestaViewSet, basename='propuesta')

propuestas_de_solicitud = PropuestaDeSolicitudViewSet.as_view({
    'get': 'list',
    'post': 'create',
})

urlpatterns = router.urls + [
    path(
        'solicitudes/<int:solicitud_pk>/propuestas/',
        propuestas_de_solicitud,
        name='solicitud-propuestas',
    ),
]
