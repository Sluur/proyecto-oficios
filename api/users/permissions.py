from rest_framework.permissions import BasePermission


class IsCliente(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.rol == 'cliente'
        )


class IsTrabajador(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.rol == 'trabajador'
        )


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and (request.user.rol == 'admin' or request.user.is_staff)
        )


class IsOwnerOrAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if request.user.is_staff or request.user.rol == 'admin':
            return True
        owner = getattr(obj, 'cliente', None) or getattr(obj, 'autor', None) or obj
        return owner == request.user
