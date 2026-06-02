from django.core.management.base import BaseCommand
from oficios.models import OficioCategoria

CATEGORIAS = [
    ("Plomería",          "plumbing",               "Caños, grifos, pérdidas, termotanques"),
    ("Electricidad",      "electric_bolt",           "Instalaciones, cortocircuitos, tableros"),
    ("Gasista",           "local_fire_department",   "Gas, calefones, estufas"),
    ("Pintura",           "format_paint",            "Interior, exterior, impermeabilización"),
    ("Albañilería",       "construction",            "Mampostería, revoques, pisos"),
    ("Fletes",            "local_shipping",          "Mudanzas, transporte de muebles"),
    ("Limpieza",          "cleaning_services",       "Hogar, oficinas, vidrios"),
    ("Cerrajería",        "lock",                    "Puertas, cerraduras, copias de llaves"),
    ("Aire acondicionado","ac_unit",                 "Instalación, carga de gas, splits"),
    ("Carpintería",       "carpenter",               "Muebles a medida, puertas, ventanas"),
]


class Command(BaseCommand):
    help = 'Carga las categorías de oficios iniciales'

    def handle(self, *args, **options):
        creadas = 0
        existentes = 0
        for nombre, icono, descripcion in CATEGORIAS:
            _, created = OficioCategoria.objects.get_or_create(
                nombre=nombre,
                defaults={'icono': icono, 'descripcion': descripcion, 'activa': True},
            )
            if created:
                creadas += 1
                self.stdout.write(self.style.SUCCESS(f'  + {nombre}'))
            else:
                existentes += 1
                self.stdout.write(f'  · {nombre} (ya existe)')

        self.stdout.write(self.style.SUCCESS(
            f'\nListo: {creadas} creadas, {existentes} ya existían.'
        ))
