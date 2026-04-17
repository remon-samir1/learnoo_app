class SocialLink {
  final String id;
  final String type;
  final SocialLinkAttributes attributes;

  SocialLink({
    required this.id,
    required this.type,
    required this.attributes,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'social-links',
      attributes: SocialLinkAttributes.fromJson(json['attributes'] ?? {}),
    );
  }
}

class SocialLinkAttributes {
  final int courseId;
  final String icon;
  final String title;
  final String subtitle;
  final String? color;
  final String link;
  final bool status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CourseData? course;

  SocialLinkAttributes({
    required this.courseId,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    required this.link,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.course,
  });

  factory SocialLinkAttributes.fromJson(Map<String, dynamic> json) {
    return SocialLinkAttributes(
      courseId: json['course_id'] ?? 0,
      icon: json['icon']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      color: json['color']?.toString(),
      link: json['link']?.toString() ?? '',
      status: json['status'] ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      course: json['course'] != null ? CourseData.fromJson(json['course']) : null,
    );
  }
}

class CourseData {
  final String id;
  final String type;
  final CourseAttributes attributes;

  CourseData({
    required this.id,
    required this.type,
    required this.attributes,
  });

  factory CourseData.fromJson(Map<String, dynamic> json) {
    return CourseData(
      id: json['data']?['id']?.toString() ?? '',
      type: json['data']?['type']?.toString() ?? 'courses',
      attributes: CourseAttributes.fromJson(json['data']?['attributes'] ?? {}),
    );
  }
}

class CourseAttributes {
  final String title;
  final String subTitle;
  final String description;
  final String thumbnail;
  final String objectives;
  final String price;
  final int maxViewsPerStudent;
  final String visibility;
  final int approval;
  final int status;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseAttributes({
    required this.title,
    required this.subTitle,
    required this.description,
    required this.thumbnail,
    required this.objectives,
    required this.price,
    required this.maxViewsPerStudent,
    required this.visibility,
    required this.approval,
    required this.status,
    this.reason,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseAttributes.fromJson(Map<String, dynamic> json) {
    return CourseAttributes(
      title: json['title']?.toString() ?? '',
      subTitle: json['sub_title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      objectives: json['objectives']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      maxViewsPerStudent: json['max_views_per_student'] ?? 0,
      visibility: json['visibility']?.toString() ?? 'public',
      approval: json['approval'] ?? 0,
      status: json['status'] ?? 0,
      reason: json['reason']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}
