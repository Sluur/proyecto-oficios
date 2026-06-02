from rest_framework.routers import SimpleRouter
from .views import TrabajadorViewSet

router = SimpleRouter()
router.register('', TrabajadorViewSet, basename='trabajador')

urlpatterns = router.urls
