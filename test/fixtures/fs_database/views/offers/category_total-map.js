function(doc) {
  if (doc.active) {
    for (category in doc.categories) {
      emit(category, 1);
    }
  }
}