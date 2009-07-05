function(doc) {
  if (doc.active && doc.state == "new") {
    emit(doc.created_on, null);
  }
}