class CounterManager {
  static int _listenAttempts = 0; // Listening attempt counter
  static const int maxAttempts = 6; // Max attempts allowed

  // Get the current attempt count
  static int get listenAttempts => _listenAttempts;

  // Increase the attempt count
  static void incrementAttempt() {
    _listenAttempts++;
  }

  // Reset the attempt count when needed
  static void resetAttempts() {
    _listenAttempts = 0;
  }

  // Check if the max attempts are reached
  static bool isMaxAttemptsReached() {
    return _listenAttempts >= maxAttempts;
  }
}
