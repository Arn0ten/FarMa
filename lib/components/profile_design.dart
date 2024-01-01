import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../models/product.dart';
import '../components/text_box.dart';
import '../pages/checkout_page.dart';
import '../pages/orders_page.dart';
import '../services/auth/auth_gate.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '../services/auth/auth_service.dart';

class ProfileDesign {
  static Widget buildProfilePage({
    required BuildContext context,
    required Map<String, dynamic> userData,
    required Function signOut,
    required Stream<List<Product>> userProducts,
    required VoidCallback pickImage,
    required VoidCallback uploadImage, // Add this line
    required String imagePath,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () {
                  _showProfilePicture(context, imagePath);
                },
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: _buildProfileImage(imagePath),
                  ),
                ),
              ),
              Positioned(
                top: 100,
                right: 198,
                child: GestureDetector(
                  onTap: pickImage, // Call pickImage directly here
                  child: Icon(
                    Icons.camera_alt,
                    size: 24,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              userData['fullName'],
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          const SizedBox(height: 30),
          ExpansionTile(
            title: const Text(
              'My details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            children: [
              _buildDetailCard('Email', userData['email'], IconlyLight.message),
              _buildDetailCard('Full Name', userData['fullName'], IconlyLight.user2),
              _buildDetailCard('Age', userData['age'].toString(), IconlyLight.calendar),
              _buildDetailCard('Address', userData['address'], IconlyLight.location),
              _buildDetailCard('Contact Number', userData['contactNumber'].toString(), IconlyLight.call),
            ],
          ),
          const SizedBox(height: 30),
          ExpansionTile(
            title: const Text(
              'My products',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            children: [
              StreamBuilder<List<Product>>(
                stream: userProducts,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(snapshot.data![index]);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error ${snapshot.error}'),
                    );
                  }
                  return const Center(
                    child: Text('No products posted yet.'),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _showLogoutDialog(context, signOut);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _updateProfileImage(File imageFile) {}

  static Future<void> _pickAndUploadImage(
      void Function() pickImage, // Adjusted parameter type
      BuildContext context,
      ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      pickImage();

      // Upload the picked image using AuthService
      try {
        await AuthService().uploadProfileImage(File(pickedFile.path));
        // Display a success message or perform other actions upon successful upload
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile image uploaded successfully.'),
          ),
        );
      } catch (e) {
        // Handle errors during the image upload
        print('Error uploading profile image: $e');
        // Display an error message or perform other error-handling actions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading profile image: $e'),
          ),
        );
      }
    }
  }



  static void _showProfilePicture(BuildContext context, String imagePath) {
    if (imagePath.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: ClipOval(
              child: Image.network(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }
  }

  static void _showLogoutDialog(BuildContext context, Function signOut) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.WARNING,
      animType: AnimType.SCALE,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        signOut();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthGate(),
          ),
        );
      },
    )..show();
  }

  static Widget _buildDetailCard(String title, String value, IconData iconData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(
          iconData,
          color: Colors.green,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }

  static Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product.image,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Error loading image');
                },
              ),
            ),
            Text('Price: \₱${product.price?.toString() ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  static Widget _buildProfileImage(String imagePath) {
    return imagePath.isEmpty
        ? const Icon(
      Icons.account_circle,
      size: 120,
      color: Colors.grey,
    )
        : ClipOval(
      child: Image.network(
        imagePath,
        fit: BoxFit.cover, // Ensures that the image covers the oval shape
        width: 120,
        height: 120,
      ),
    );
  }

}