import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ndiscord/services/ws_service.dart';

class WebRTCService {
  final WebSocketService _ws;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};

  final StreamController<MediaStream> _remoteStreamController = StreamController.broadcast();
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;

  final StreamController<MediaStream> _localStreamController = StreamController.broadcast();
  Stream<MediaStream> get onLocalStream => _localStreamController.stream;

  WebRTCService(this._ws);

  Future<void> initialize() async {
    _ws.addHandler(_handleSignal);
  }

  void _handleSignal(Map<String, dynamic> data) {
    if (data['type'] != 'webrtc_signal') return;

    final fromUserId = data['from_user_id'] as String;
    final signal = data['signal'] as Map<String, dynamic>;

    if (signal['type'] == 'offer') {
      _handleOffer(fromUserId, signal);
    } else if (signal['type'] == 'answer') {
      _handleAnswer(fromUserId, signal);
    } else if (signal['type'] == 'candidate') {
      _handleCandidate(fromUserId, signal);
    }
  }

  Future<MediaStream> startLocalAudio() async {
    final constraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localStreamController.add(_localStream!);
    return _localStream!;
  }

  Future<MediaStream> startScreenShare() async {
    final constraints = {
      'audio': true,
      'video': {
        'cursor': 'always',
        'width': {'ideal': 1920},
        'height': {'ideal': 1080},
        'frameRate': {'ideal': 30},
      },
    };
    final stream = await navigator.mediaDevices.getDisplayMedia(constraints);
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:localhost:3478'},
      ],
    };

    final pc = await createPeerConnection(config);

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      }
    };

    pc.onIceCandidate = (candidate) {
      _ws.sendWebRTCSignal(peerId, {
        'type': 'candidate',
        'candidate': candidate.toMap(),
      });
    };

    _peerConnections[peerId] = pc;
    return pc;
  }

  Future<void> call(String peerId) async {
    final pc = await _createPeerConnection(peerId);

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _ws.sendWebRTCSignal(peerId, {
      'type': 'offer',
      'sdp': offer.toMap(),
    });
  }

  Future<void> _handleOffer(String peerId, Map<String, dynamic> signal) async {
    final pc = await _createPeerConnection(peerId);

    final offer = RTCSessionDescription(signal['sdp']['sdp'], signal['sdp']['type']);
    await pc.setRemoteDescription(offer);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _ws.sendWebRTCSignal(peerId, {
      'type': 'answer',
      'sdp': answer.toMap(),
    });
  }

  Future<void> _handleAnswer(String peerId, Map<String, dynamic> signal) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    final answer = RTCSessionDescription(signal['sdp']['sdp'], signal['sdp']['type']);
    await pc.setRemoteDescription(answer);
  }

  Future<void> _handleCandidate(String peerId, Map<String, dynamic> signal) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    final candidate = RTCIceCandidate(
      signal['candidate']['candidate'],
      signal['candidate']['sdpMid'],
      signal['candidate']['sdpMLineIndex'],
    );
    await pc.addCandidate(candidate);
  }

  Future<void> muteAudio(bool muted) async {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
  }

  Future<void> stopAll() async {
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;

    _remoteStream?.getTracks().forEach((t) => t.stop());
    _remoteStream = null;
  }

  void dispose() {
    stopAll();
    _remoteStreamController.close();
    _localStreamController.close();
  }
}
