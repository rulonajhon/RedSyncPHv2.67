import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Initialize Firebase (you may need to configure this based on your setup)
  await Firebase.initializeApp();

  print('Creating test post report...');

  try {
    final firestore = FirebaseFirestore.instance;
    
    // Create a test post report
    await firestore.collection('post_reports').add({
      'postId': 'test-post-123',
      'postContent': 'This is a test post that has been reported',
      'postAuthorId': 'test-user-456',
      'postAuthorName': 'Test User',
      'postTimestamp': FieldValue.serverTimestamp(),
      'reporterId': 'reporter-789',
      'reporterName': 'Test Reporter',
      'reason': 'Spam/Advertisement',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'adminNotes': '',
    });

    print('✅ Test report created successfully!');
    print('Now check the Admin Dashboard > Reports tab');
    
  } catch (e) {
    print('❌ Error creating test report: $e');
  }
}
