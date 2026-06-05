import '../models/match.dart';
import '../models/statistics.dart';

class StatisticsService {
  Statistics calculateStatistics(List<GameMatch> matches) {
    return Statistics.fromMatches(matches);
  }
}
