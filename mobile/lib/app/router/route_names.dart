/// Route paths and names, in one place so no call site hardcodes a string.
///
/// Paths are what appear in the URL; names are what `context.goNamed` takes.
/// Prefer the named form — a path can change without touching call sites.
abstract final class RouteNames {
  // Bootstrap
  static const String welcome = 'welcome';
  static const String welcomePath = '/';

  // Auth
  static const String login = 'login';
  static const String loginPath = '/login';

  static const String register = 'register';
  static const String registerPath = '/register';

  static const String forgotPassword = 'forgot-password';
  static const String forgotPasswordPath = '/forgot-password';

  static const String resetPassword = 'reset-password';
  static const String resetPasswordPath = '/reset-password';

  // Main shell
  static const String today = 'today';
  static const String todayPath = '/today';

  static const String habits = 'habits';
  static const String habitsPath = '/habits';

  static const String addHabit = 'add-habit';
  static const String addHabitPath = 'add';

  static const String habitDetail = 'habit-detail';

  /// Nested under [habitsPath]; use [habitDetailLocation] to build the URL.
  static const String habitDetailPath = ':habitId';

  static String habitDetailLocation(String habitId) => '$habitsPath/$habitId';

  static const String insights = 'insights';
  static const String insightsPath = '/insights';

  static const String profile = 'profile';
  static const String profilePath = '/profile';

  static const String editProfile = 'edit-profile';
  static const String editProfilePath = 'edit';

  // Routines
  static const String routines = 'routines';
  static const String routinesPath = '/routines';

  static const String routineDetail = 'routine-detail';
  static const String routineDetailPath = ':routineId';
  static String routineDetailLocation(String routineId) => '$routinesPath/$routineId';

  static const String createRoutine = 'create-routine';
  static const String createRoutinePath = 'create';

  static const String editRoutine = 'edit-routine';
  static const String editRoutinePath = ':routineId/edit';
  static String editRoutineLocation(String routineId) => '$routinesPath/$routineId/edit';

  static const String routineExecution = 'routine-execution';
  static const String routineExecutionPath = ':routineId/execute';
  static String routineExecutionLocation(String routineId) => '$routinesPath/$routineId/execute';

  static const String routineCompleted = 'routine-completed';
  static const String routineCompletedPath = ':routineId/completed';
  static String routineCompletedLocation(String routineId) => '$routinesPath/$routineId/completed';

  // Offline
  static const String offline = 'offline';
  static const String offlinePath = '/offline';

  /// Routes reachable while signed out. Everything else redirects to login.
  static const Set<String> publicPaths = {
    welcomePath,
    loginPath,
    registerPath,
    forgotPasswordPath,
    resetPasswordPath,
    offlinePath,
  };
}
