part of dart_airtable;

const _defaultAirtableApiUrl = 'https://api.airtable.com';

class Airtable {
  final String apiKey;
  final String projectBase;
  final String apiUrl;
  http.Client client;

  Airtable({
    @required this.apiKey,
    @required this.projectBase,
    this.apiUrl = _defaultAirtableApiUrl,
    this.client,
  }) : assert(apiUrl != null) {
    client = client ?? http.Client();
  }

  Future<List<AirtableRecord>> getAllRecords(String recordName,
      {int maxRecords, int pageSize}) async {
    var response = await client.get(_recordApiUrl(recordName), headers: {
      'Authorization': 'Bearer $apiKey',
    });

    Map<String, dynamic> body = jsonDecode(response.body);
    if (body == null) {
      return [];
    }

    var records = List<Map<String, dynamic>>.from(body['records']);

    if (records == null || records.isEmpty) {
      return [];
    }

    return records
        .map<AirtableRecord>(
            (Map<String, dynamic> record) => AirtableRecord.fromJSON(record))
        .toList();
  }

  Future<AirtableRecord> createRecord(
      String recordName, AirtableRecord record) async {
    var records = await createRecords(recordName, [record]);
    return records == null || records.isEmpty ? null : records.first;
  }

  Future<List<AirtableRecord>> createRecords(
      String recordName, List<AirtableRecord> records) async {
    var requestBody = {
      'records': records.map((record) => record.toJSON()).toList(),
    };

    var response = await client.post(
      _recordApiUrl(recordName),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.body == null ||
        response.statusCode == HttpStatus.unprocessableEntity) {
      return [];
    }

    Map<String, dynamic> body = jsonDecode(response.body);
    if (body == null || body['error'] != null) {
      return [];
    }

    final savedRecords = List<Map<String, dynamic>>.from(body['records']);

    if (savedRecords == null || savedRecords.isEmpty) {
      return [];
    }

    return savedRecords
        .map<AirtableRecord>(
            (Map<String, dynamic> record) => AirtableRecord.fromJSON(record))
        .toList();
  }

  Future<AirtableRecord> getRecord(String recordName, String recordId) async {
    var response =
        await client.get('${_recordApiUrl(recordName)}/$recordId', headers: {
      'Authorization': 'Bearer $apiKey',
    });

    if (response.statusCode == HttpStatus.notFound ||
        response.body == null ||
        response.body.isEmpty) {
      return null;
    }

    Map<String, dynamic> body = jsonDecode(response.body);

    return AirtableRecord.fromJSON(body);
  }

  Future<List<AirtableRecord>> updateRecords(
      String recordName, List<AirtableRecord> records) async {
    var requestBody = {
      'records': records.map((record) => record.toJSON()).toList(),
    };

    var response = await client.patch(
      _recordApiUrl(recordName),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.body == null ||
        response.statusCode == HttpStatus.unprocessableEntity) {
      return [];
    }

    Map<String, dynamic> body = jsonDecode(response.body);
    if (body == null || body['error'] != null) {
      return [];
    }

    final savedRecords = List<Map<String, dynamic>>.from(body['records']);

    if (savedRecords == null || savedRecords.isEmpty) {
      return [];
    }

    return savedRecords
        .map<AirtableRecord>(
            (Map<String, dynamic> record) => AirtableRecord.fromJSON(record))
        .toList();
  }

  Future<AirtableRecord> updateRecord(
      String recordName, AirtableRecord record) async {
    var records = await updateRecords(recordName, [record]);
    return records == null || records.isEmpty ? null : records.first;
  }

  Future<List<String>> deleteRecords(
      String recordName, List<AirtableRecord> records) async {
    var response = await client.delete(
      _recordApiUrl(recordName, {
        'records':
            jsonEncode(records.map<String>((record) => record.id).toList())
      }),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.body == null) {
      return [];
    }

    Map<String, dynamic> body = jsonDecode(response.body);
    if (body == null || body['error'] != null) {
      return [];
    }

    final resultRecords = List<Map<String, dynamic>>.from(body['records']);

    return resultRecords
        .where((record) => record['deleted'] == true)
        .map<String>((record) => record['id'])
        .toList();
  }

  Uri _recordApiUrl(String recordName, [Map<String, String> queryParams]) {
    var url = apiUrl.replaceAll(RegExp('^https?:\/\/'), '');
    return Uri.https(url, '/v0/${projectBase}/${recordName}', queryParams);
  }
}