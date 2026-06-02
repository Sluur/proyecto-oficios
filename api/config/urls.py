from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/', include('users.urls')),
    path('api/v1/categorias/', include('oficios.urls')),
    path('api/v1/', include('solicitudes.urls')),
    path('api/v1/', include('resenas.urls')),
    path('api/v1/trabajadores/', include('users.urls_trabajadores')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
