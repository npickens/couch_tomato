function(doc) {
  if (doc.active && doc.user_name && doc.state == 'in_progress') {
    emit(doc.user_name, doc);
  }
}