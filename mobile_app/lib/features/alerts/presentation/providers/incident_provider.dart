import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/alerts/data/datasources/incident_remote_data_source.dart';
import 'package:mobile_app/features/alerts/data/repositories/incident_repository_impl.dart';
import 'package:mobile_app/features/alerts/domain/repositories/incident_repository.dart';
import 'package:mobile_app/features/alerts/domain/usecases/submit_incident_report.dart';

// Nếu project đã có provider chung cho SupabaseClient thì thay
// Supabase.instance.client bằng ref.watch(<provider đó>).
final incidentRemoteDataSourceProvider =
    Provider<IncidentRemoteDataSource>((ref) {
  return IncidentRemoteDataSource(Supabase.instance.client);
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepositoryImpl(ref.watch(incidentRemoteDataSourceProvider));
});

final submitIncidentReportProvider = Provider<SubmitIncidentReport>((ref) {
  return SubmitIncidentReport(ref.watch(incidentRepositoryProvider));
});