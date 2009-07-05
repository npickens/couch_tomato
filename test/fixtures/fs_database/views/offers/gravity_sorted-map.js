function(doc) {
  if (doc.active) {
    emit(doc.gravity[doc.last_revision], doc);
  }
}