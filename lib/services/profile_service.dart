import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final supabase = Supabase.instance.client;

  Future<String> getFullName() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return 'Guest';
    }

    final response = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .single();

    return response['full_name'] as String;
  }
}
