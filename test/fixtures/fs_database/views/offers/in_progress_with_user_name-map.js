function(doc) {
  if (doc.active && doc.user_name && doc.state == 'in_progress') {
    emit(doc.publisher_nickname, {'user_name' : doc.user_name, 'publisher_nickname' : doc.publisher_nickname});
  }
}