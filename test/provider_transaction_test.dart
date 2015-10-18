library tekartik_app_transaction_test;

import 'package:idb_shim/idb_client.dart';
import 'package:tekartik_idb_provider/provider.dart';

import 'test_common.dart';

void main() {
  testMain(idbMemoryContext);
}

void testMain(TestContext context) {
  IdbFactory idbFactory = context.factory;
  //devWarning;
  // TODO Add store transaction test
  group('transaction', () {
    //String providerName = "test";
    String storeName = "store";
    String indexName = "index";
    String indexKey = "my_key";

    DynamicProvider provider;
    ProviderTransaction transaction;

    _setUp() {
      provider =
          new DynamicProvider(idbFactory, new ProviderDbMeta(context.dbName));
      return provider.delete().then((_) {
        ProviderIndexMeta indexMeta =
            new ProviderIndexMeta(indexName, indexKey);
        provider.addStore(new ProviderStoreMeta(storeName,
            indecies: [indexMeta], autoIncrement: true));
        return provider.ready;
      });
    }
    tearDown(() {
      return new Future.value(() {
        if (transaction != null) {
          return transaction.completed;
        }
      }).then((_) {
        provider.close();
      });
    });

    test('store_cursor', () async {
      await _setUp();
      ProviderStoreTransaction storeTxn =
          provider.storeTransaction(storeName, true);
      // put one with a key one without
      storeTxn.put({"value": "value1"});
      storeTxn.put({"value": "value2"});
      await storeTxn.completed;

      ProviderStoreTransaction txn =
          provider.storeTransaction(storeName, false);
      List<Map> data = [];
      //List<String> keyData = [];
      txn.openCursor().listen((CursorWithValue cwv) {
        data.add(cwv.value);
      });

      // listed last
      await txn.completed;
      expect(data, [
        {"value": "value1"},
        {"value": "value2"}
      ]);
    });

    test('store_index', () async {
      await _setUp();
      ProviderStoreTransaction storeTxn =
          provider.storeTransaction(storeName, true);
      // put one with a key one without
      storeTxn.put({"value": "value1"});
      storeTxn.put({"my_key": 2, "value": "value2"});
      storeTxn.put({"value": "value3"});
      storeTxn.put({"my_key": 1, "value": "value4"});
      await storeTxn.completed;

      ProviderIndexTransaction txn =
          provider.indexTransaction(storeName, indexName);
      List<Map> data = [];
      List<String> keyData = [];
      txn.openCursor().listen((CursorWithValue cwv) {
        data.add(cwv.value);
      });
      txn.openKeyCursor().listen((Cursor c) {
        keyData.add(c.key);
      });

      // listed last
      await txn.completed;
      expect(data.length, 2);
      expect(data[0], {"my_key": 1, "value": "value4"});
      expect(data[1], {"my_key": 2, "value": "value2"});
      expect(keyData.length, 2);
      expect(keyData[0], 1);
      expect(keyData[1], 2);
    });
  });
}
//class TestApp extends ConsoleApp {
//
//}
