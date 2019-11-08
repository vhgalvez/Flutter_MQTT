import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mqtt_app/mqtt/state/MQTTAppState.dart';
import 'package:flutter_mqtt_app/mqtt/MQTTManager.dart';
import 'dart:io' show Platform;

class MQTTView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MQTTViewState();
  }
}

class _MQTTViewState extends State<MQTTView> {
  final TextEditingController _hostTextController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  MQTTAppState currentAppState;
  MQTTManager manager;

  @override
  void initState() {
    super.initState();

    _hostTextController.addListener(_printLatestValue);
    _messageTextController.addListener(_printLatestValue);
    _topicTextController.addListener(_printLatestValue);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.
    _hostTextController.dispose();
    _messageTextController.dispose();
    _topicTextController.dispose();
    super.dispose();
  }

  _printLatestValue() {
    print("Second text field: ${_hostTextController.text}");
    print("Second text field: ${_messageTextController.text}");
    print("Second text field: ${_topicTextController.text}");
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MQTTAppState>(context);
    currentAppState = appState;
    var scaffold =
        Scaffold(appBar: _buildAppBar(context), body: _buildColumn());
    return scaffold;
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('MQTT'),
      backgroundColor: Colors.greenAccent,
    );
  }

  Widget _buildColumn() {
    return Column(
      children: <Widget>[
        _buildConnectionStateText(
            _prepareStateMessageFrom(currentAppState.getAppConnectionState)),
        _buildEditableColumn(),
        _buildScrollableTextWith(currentAppState.getHistoryText)
      ],
    );
  }

  Widget _buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          _buildTextFieldWith(_hostTextController, 'Enter broker address',currentAppState.getAppConnectionState),
          SizedBox(height: 10),
          _buildTextFieldWith(
              _topicTextController, 'Enter a topic to subscribe or listen', currentAppState.getAppConnectionState),
          SizedBox(height: 10),
          _buildPublishMessageRow(),
          SizedBox(height: 10),
          _buildConnecteButtonFrom(currentAppState.getAppConnectionState)
        ],
      ),
    );
  }

  Widget _buildPublishMessageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: _buildTextFieldWith(_messageTextController, 'Enter a message', currentAppState.getAppConnectionState),
        ),
        _buildSendButtonFrom(currentAppState.getAppConnectionState)
      ],
    );
  }

  Widget _buildConnectionStateText(String status) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
              color: Colors.deepOrangeAccent,
              child: Text(status, textAlign: TextAlign.center)),
        ),
      ],
    );
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if ((controller == _messageTextController &&
        state == MQTTAppConnectionState.connected)) {
      shouldEnable = true;
    } else if ((controller == _hostTextController &&
        state == MQTTAppConnectionState.disconnected) || (controller == _topicTextController &&
        state == MQTTAppConnectionState.disconnected)) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  Widget _buildScrollableTextWith(String text) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: 400,
        height: 300,
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
    );
  }

  String _prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        return "Connected";
      case MQTTAppConnectionState.connecting:
        return "Connecting";
      case MQTTAppConnectionState.disconnected:
        return "Disconnected";
    }
  }

  void _configureAndConnect() {
    manager = MQTTManager(
        host: _hostTextController.text,
        topic: _topicTextController.text,
        identifier: 'ios',
        state: currentAppState);
    manager.initializeMQTTClient();
    manager.connect();
  }

  void _publishMessage(String text) {
    String os_Prefix = "Flutter_iOS";
    if(Platform.isAndroid){
      os_Prefix = "Flutter_Android";
    }
    final message = os_Prefix + " says: " + text;
    manager.publish(message);
    _messageTextController.clear();
  }

  Widget _buildConnecteButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          child: RaisedButton(
            color: Colors.lightBlueAccent,
            child: Text('Connect'),
            onPressed: state == MQTTAppConnectionState.disconnected
                ? _configureAndConnect
                : null, //
          ),
        ),
      ],
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return RaisedButton(
      color: Colors.green,
      child: Text('Send'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null, //
    );
  }
}
