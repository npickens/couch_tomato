function(doc) {
  if (doc.active) {
    emit(doc.created_on, doc);
  }
}