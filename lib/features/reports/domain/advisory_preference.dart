enum AdvisoryStyle {
  balanced,
  frugal,
  growth,
  concise,
}

extension AdvisoryStyleExtension on AdvisoryStyle {
  String get label {
    switch (this) {
      case AdvisoryStyle.balanced:
        return 'Seimbang';
      case AdvisoryStyle.frugal:
        return 'Ketat / Hemat';
      case AdvisoryStyle.growth:
        return 'Pertumbuhan Investasi';
      case AdvisoryStyle.concise:
        return 'Ringkas Eksekutif';
    }
  }

  String get shortDescription {
    switch (this) {
      case AdvisoryStyle.balanced:
        return 'Alokasi terukur 50/30/20 menjaga kualitas hidup dan tabungan.';
      case AdvisoryStyle.frugal:
        return 'Fokus pangkas belanja diskresioner untuk percepatan target tabungan.';
      case AdvisoryStyle.growth:
        return 'Maksimalkan tingkat tabungan untuk akumulasi modal investasi.';
      case AdvisoryStyle.concise:
        return 'Ringkasan 3 poin aksi cepat tanpa istilah teknis berbelit.';
    }
  }

  String get promptKey {
    switch (this) {
      case AdvisoryStyle.balanced:
        return 'balanced';
      case AdvisoryStyle.frugal:
        return 'frugal';
      case AdvisoryStyle.growth:
        return 'growth';
      case AdvisoryStyle.concise:
        return 'concise';
    }
  }
}
