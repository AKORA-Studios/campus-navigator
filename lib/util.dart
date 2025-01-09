String ds_to_time(int ds) {
  const times = [
    "7:30 - 9:00",
    "9:20 - 10:50",
    "11:10 - 12:40",
    "13:00 - 14:00",
    "14:50 - 16:20",
    "16:40 - 18:10",
    "18:30 - 20:00"
  ];
  return ds > times.length ? "$ds. DS" : times[ds - 1];
}
