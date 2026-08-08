import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/voice_expense_service.dart';

class VoiceExpenseScreen extends StatefulWidget {
  const VoiceExpenseScreen({super.key});

  @override
  State<VoiceExpenseScreen> createState() => _VoiceExpenseScreenState();
}

class _VoiceExpenseScreenState extends State<VoiceExpenseScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _hasResult = false;
  String _transcript = '';
  String? _error;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'cash_out';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          if (_transcript.trim().isNotEmpty) {
            _processTranscript();
          }
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _error = 'Mic me masla hua. Dobara try karein.';
        });
      },
    );
    setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      setState(() => _error = 'Speech recognition available nahi hai is device pe.');
      return;
    }

    setState(() {
      _transcript = '';
      _error = null;
      _hasResult = false;
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() => _transcript = result.recognizedWords);
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_PK',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_transcript.trim().isNotEmpty) {
      _processTranscript();
    }
  }

  Future<void> _processTranscript() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await VoiceExpenseService.parse(_transcript);
      setState(() {
        _amountController.text = result.amount != null ? result.amount!.toStringAsFixed(0) : '';
        _descriptionController.text = result.description ?? _transcript;
        _type = result.type;
        _hasResult = true;
      });
    } on VoiceExpenseException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Samajh nahi saka. Dobara try karein ya manually add karein.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _confirm() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sahi amount likhein')),
      );
      return;
    }

    Navigator.pop(context, {
      'amount': amount,
      'type': _type,
      'description': _descriptionController.text.trim(),
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Voice Add'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Mic button
            Center(
              child: GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red : Colors.indigo,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : Colors.indigo).withOpacity(0.3),
                        blurRadius: _isListening ? 24 : 12,
                        spreadRadius: _isListening ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _isListening ? 'Sun raha hoon... (dobara tap karein rokne ke liye)' : 'Bolne ke liye tap karein',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),

            if (_transcript.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '"$_transcript"',
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15),
                ),
              ),
            const SizedBox(height: 16),

            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Samajh raha hoon...'),
                    ],
                  ),
                ),
              ),

            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            if (_hasResult && !_isProcessing) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'cash_in'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'cash_in' ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Cash In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _type == 'cash_in' ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'cash_out'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'cash_out' ? Colors.red : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Cash Out',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _type == 'cash_out' ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.notes),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue to Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}