module Rake
  class Task
    alias_method :invoke_without_appsignal, :invoke

    def invoke(*args)
      invoke_with_appsignal(*args)
    end

    def invoke_with_appsignal(*args)
      transaction = Appsignal::Transaction.create(
        SecureRandom.uuid,
        ENV,
        :kind => 'background_job',
        :action => name,
        :params => args
      )
      Appsignal.logger.info("Invoking rake task with AppSignal")
      invoke_without_appsignal(*args)
    rescue => exception
      Appsignal.logger.info("Excepion caught")
      Appsignal.logger.info("Appsignal active? #{Appsignal.active?.inspect}")
      Appsignal.logger.info("Ignored exception? #{Appsignal.is_ignored_exception?(exception).inspect}")

      if Appsignal.active? && !Appsignal.is_ignored_exception?(exception)
        Appsignal.logger.info("Added exception to transaction")
        transaction.add_exception(exception)
      end
      raise exception
    ensure
      transaction.complete!
      Appsignal.agent.send_queue if Appsignal.active?
    end
  end
end
