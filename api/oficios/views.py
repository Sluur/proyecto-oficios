from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from users.permissions import IsAdmin
from .models import OficioCategoria
from .serializers import OficioCategoriaSerializer


class OficioCategoriaViewSet(viewsets.ModelViewSet):
    serializer_class = OficioCategoriaSerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.rol == 'admin':
            return OficioCategoria.objects.all()
        return OficioCategoria.objects.filter(activa=True)

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [IsAuthenticated()]
        return [IsAdmin()]
