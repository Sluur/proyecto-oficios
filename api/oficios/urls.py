from rest_framework.routers import SimpleRouter
from .views import OficioCategoriaViewSet

router = SimpleRouter()
router.register('', OficioCategoriaViewSet, basename='oficio-categoria')

urlpatterns = router.urls
