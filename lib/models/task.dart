class Task {
  // ... existing properties ...
  int executedMinutes;
  int totalMinutes;

  Task({
    // ... existing parameters ...
    this.executedMinutes = 0,
    this.totalMinutes = 25,  // 默认25分钟
  });
} 