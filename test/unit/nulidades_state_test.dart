import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/services/nulidades_service.dart';
import 'package:multas_ar/features/nulidades/bloc/nulidades_bloc.dart';

void main() {
  CausalNulidad causal(String id) => CausalNulidad(
        id: id,
        titulo: id,
        descripcion: 'Descripción',
        norma: 'Norma pendiente de verificación',
        tipo: TipoNulidad.relativa,
      );

  ResultadoNulidades resultado(String id) => ResultadoNulidades(
        causalesDetectadas: [causal(id)],
        causalesPotenciales: const [],
        recomendacion: 'Revisar con profesional',
        tieneNulidadAbsoluta: false,
      );

  test('dos análisis del mismo caso con causales distintas no son iguales', () {
    final primero = NulidadesAnalizado(
      casoId: 'caso-1',
      resultado: resultado('causal-a'),
    );
    final segundo = NulidadesAnalizado(
      casoId: 'caso-1',
      resultado: resultado('causal-b'),
    );

    expect(primero, isNot(equals(segundo)));
  });

  test('análisis de casos distintos no son iguales aunque coincidan las causales', () {
    final primero = NulidadesAnalizado(
      casoId: 'caso-1',
      resultado: resultado('causal-a'),
    );
    final segundo = NulidadesAnalizado(
      casoId: 'caso-2',
      resultado: resultado('causal-a'),
    );

    expect(primero, isNot(equals(segundo)));
  });
}
