require File.expand_path(Rails.root)+'/lib/socrata'
class Violation < ActiveRecord::Base

  SOCRATA_ATTRIBUTE_REMAPPING = {
    "casenumber" => "case_number",
    "casesakey" => "case_sakey",
    "cleardate" => "clear_date",
    "clearedby" => "cleared_by",
    "entrydate" => "entry_date",
    "issuedby" => "issued_by",
    "issueddate" => "issued_date",
    "lastupdate" => "last_update",
    "majorviolation" => "major_violation",
    "numberofitems" => "number_of_items",
    "reissuedate" => "reissue_date",
    "reissuedby" => "reissued_by",
    "responsibleparty" => "responsible_party",
    "stapt" => "st_apt",
    "stname" => "st_name",
    "stnumber" => "st_number",
    "sttype" => "st_type",
    "violationcleared" => "violation_cleared",
    "violationcode" => "violation_code",
    "violationdescription" => "violation_description",
    "violationissued" => "violation_issued",
    "violationreissued" => "violation_reissued",
    "violationsakey" => "violation_sakey",
    "violationid" => "violation_id",
    "fulladdress" => "full_address",
    "xcoord" => "x_coord",
    "ycoord" => "y_coord",
    "adsakey" => "ad_sakey",
    "ownermailzip" => "owner_mailzip",
    "adlot" => "ad_lot",
    "closereason" => "close_reason",
    "ownername" => "owner_name",
    "ownermailstate" => "owner_mailstate",
    "casenotes" => "case_notes",
    "duedate" => 'due_date',
    "ownermailcity" => "owner_mailcity",
    "ownermailaddr2" => "owner_mailaddr2",
    "censustract" => "census_tract",
    "rentalstatus" => "rental_status",
    "ownername2" => "owner_name2",
    "closedate" => "close_date",
    "usecode" => "use_code",
    "assignedinspcode" => "assigned_insp_code",
    "ownermailaddr" => "owner_mailaddr",
    "casestatus" => "case_status",
    "casetype" => "case_type",
    "annexdate" => "annex_date"
  }


  belongs_to :loe_case

  scope :for_case, -> (loe_case_id) { where(loe_case_id: loe_case_id).order('case_sakey') }

  def self.seed
    Socrata.seed self, Socrata.violation_dataset_id
  end

  def assign_from_socrata(socrata_result, cache=nil)
    cache ||= {}
    socrata_result.keys.each do |key|
      col = self.class::SOCRATA_ATTRIBUTE_REMAPPING[key] || key
      raise "undefined attribute: #{key}\n#{socrata_result.to_json}" unless self.class.column_names.include?(col)
      unless socrata_result[key].strip == "NULL"
        case col.to_s
        when "case_sakey", "case_number", "violation_sakey", "number_of_items"
          self[col.to_sym] = socrata_result[key].strip.to_i
          if col == "case_number"
            if cache[self[col.to_sym]]
              self.loe_case_id = cache[self[col.to_sym]]
            else
              self.loe_case_id = LoeCase.where('case_number = ?',self[col.to_sym]).limit(1).select('id').first.try(:id)
            end
          end
        when "clear_date", "entry_date", "last_update", "issued_date", "reissue_date"
          begin
            if socrata_result[key].strip.match(/^\d+\/\d+\/\d+ \d+:\d+$/)
              self[col.to_sym] = Time.strptime(socrata_result[key].strip,"%m/%d/%Y %H:%M")
            elsif socrata_result[key].strip.match(/^\d{1,2}\/\d{1,2}\/\d{4} \d{1,2}:\d{2}:\d{2} (a|p)m$/i)
              self[col.to_sym] = Time.strptime(socrata_result[key].strip.upcase,"%m/%d/%Y %I:%M")
              if socrata_result[key].strip.match(/pm$/i)
                self[col.to_sym].advance(hours: 12)
              end
            else
              self[col.to_sym] = Time.parse(socrata_result[key].strip)
            end
          rescue ArgumentError => e
            puts "val: #{socrata_result[key].strip}"
            raise e
          end
        else self[col.to_sym] = socrata_result[key].strip
        end
      end
    end
  end

end
