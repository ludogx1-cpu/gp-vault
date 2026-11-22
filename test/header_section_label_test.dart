import 'package:flutter_test/flutter_test.dart';
import 'package:gp_faucet/widgets/global_app_bar.dart';

void main() {
  test('each part of the app gets its own label next to Golden Paw', () {
    expect(sectionForPath('/faucet'), 'Faucet');
    expect(sectionForPath('/book-of-dog'), 'Book Of Dog');
    expect(sectionForPath('/book-of-dog/post/abc'), 'Book Of Dog');
    expect(sectionForPath('/staking'), 'Bonus Vault');
    expect(sectionForPath('/account'), 'Account');
    expect(sectionForPath('/'), isNull);
    expect(sectionForPath('/somewhere-else'), isNull);
  });
}
