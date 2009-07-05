function(doc) {
  if (doc.active) {
    emit(doc.publisher_nickname, null);
  }
}