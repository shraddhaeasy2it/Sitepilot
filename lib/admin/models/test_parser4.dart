void main() {
  dynamic a = [];
  try {
    print(a['details']);
  } catch (e) {
    print("Error: \$e");
  }
}
