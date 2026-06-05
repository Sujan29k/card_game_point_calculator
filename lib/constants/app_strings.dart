class AppStrings {
  static const appTitle = 'Card Score Tracker';

  static const gameTypeCallbreak = 'callbreak';
  static const gameTypeMarriage = 'marriage';

  static const homeTitle = 'Card Score Tracker';
  static const continueMatch = 'Continue Match';
  static const startMatch = 'Start Match';
  static const endGame = 'End Game';
  static const addRound = 'Add Round';
  static const editRound = 'Edit Round';
  static const deleteRound = 'Delete Round';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const confirm = 'Confirm';
  static const delete = 'Delete';
  static const undo = 'Undo';

  static const callbreakTitle = 'Call Break';
  static const marriageTitle = 'Marriage';
  static const callbreakDesc = '4 players, bids and tricks, race to 17.';
  static const marriageDesc = '3-6 players, bonus hands, highest score wins.';

  static const recentMatches = 'Recent Matches';
  static const noRecentMatches = 'No matches yet. Start a game to see history.';
  static const statistics = 'Statistics';
  static const history = 'History';
  static const details = 'Details';

  static const players = 'Players';
  static const playerName = 'Player Name';
  static const playerDefault = 'Player';
  static const winningScore = 'Winning Score';
  static const round = 'Round';
  static const rounds = 'Rounds';
  static const total = 'Total';
  static const numberSymbol = '#';
  static const winner = 'Winner';
  static const totalMatches = 'Total Matches';
  static const totalPlayers = 'Total Players';
  static const topWinner = 'Top Winner';
  static const highestScore = 'Highest Score';
  static const averageScore = 'Average Score';
  static const mostFrequentWinner = 'Most Frequent Winner';
  static const duration = 'Duration';

  static const bid = 'Bid';
  static const tricksWon = 'Tricks Won';
  static const points = 'Points';
  static const maal = 'Maal';
  static const seen = 'Seen';
  static const marriage = 'Marriage';

  static const bonusConfig = 'Bonus Configuration';
  static const maalBonus = 'Maal Bonus';
  static const seenBonus = 'Seen Bonus';
  static const marriageBonus = 'Marriage Bonus';

  static const emptyRounds = 'No rounds yet. Add the first round.';
  static const noActiveMatch = 'No active match. Start a new game.';
  static const noRoundsShort = 'No rounds yet.';
  static const confirmDeleteRound = 'Delete this round?';
  static const confirmEndGame = 'End this game now?';
  static const confirmDeleteMatch = 'Delete this match?';
  static const separator = '•';
  static const placeholder = '-';

  static const addPlayer = 'Add Player';
  static const removePlayer = 'Remove Player';
  static const valueInvalid = 'Enter a valid value';

  static const lightMode = 'Light Mode';
  static const darkMode = 'Dark Mode';

  static const numberOfRounds = 'Number of Rounds';
  static const numberOfRoundsHint = '0 = unlimited (manual end)';
  static const specialRound = 'Special Round';
  static const specialGame = 'Special';
  static const regularGame = 'Regular';
  static const doubleMoney = 'Double Money';
  static const specialWin = 'Special Win!';
  static const specialScores = 'Special Scores';
}

class AppRoutes {
  static const home = '/';
  static const callbreakSetup = '/callbreak/setup';
  static const callbreakGame = '/callbreak/game';
  static const marriageSetup = '/marriage/setup';
  static const marriageGame = '/marriage/game';
  static const history = '/history';
  static const historyDetail = '/history/detail';
  static const statistics = '/statistics';
}
