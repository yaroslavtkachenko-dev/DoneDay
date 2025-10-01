//
//  TaskEntity+CoreDataProperties.swift
//  
//
//  Created by Yaroslav Tkachenko on 01.10.2025.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias TaskEntityCoreDataPropertiesSet = NSSet

extension TaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var completedAt: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isDelete: Bool
    @NSManaged public var notes: String?
    @NSManaged public var priority: Int16
    @NSManaged public var sortOrder: Int32
    @NSManaged public var startDate: Date?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var area: AreaEntity?
    @NSManaged public var project: ProjectEntity?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for tags
extension TaskEntity {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: TagEntity)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: TagEntity)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

extension TaskEntity : Identifiable {

}
